import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:guachinches/ui/pages/advance_search/list_theme.dart';
import 'package:guachinches/ui/pages/advance_search/widgets/list_glyph.dart';
import 'package:guachinches/ui/pages/map/map_logic.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// Piezas flotantes del mapa (tableros TabMapa, MapaCoche, MapaEmpujado):
/// cápsulas de cristal, chips, botones redondos y tarjetas de estado.
///
/// Candidatas a subir a `lib/ui/theme`: [MapGlassCapsule] (cristal claro
/// sobre mapa), [MapVolcanoGlyph] (volcán con tinta de noche) y
/// [MapSegmented] (control segmentado de cristal).

/// Icono «localizar» de los tableros (flecha en contorno).
final String kMapLocateIcon =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
    'stroke="currentColor" stroke-width="2.4" stroke-linejoin="round">'
    '<path d="M20.5 3.5L3.5 10.6l7 2.4 2.4 7z"/></svg>';

/// Cristal claro (`glass` + `glassEdge` + sombra e1) en cápsula.
class MapGlassCapsule extends StatelessWidget {
  final Widget child;
  final double? height;
  final EdgeInsetsGeometry padding;
  final double radius;
  final List<BoxShadow>? shadow;

  const MapGlassCapsule({
    super.key,
    required this.child,
    this.height,
    this.padding = EdgeInsets.zero,
    this.radius = GmRadius.pill,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return GmGlass(
      borderRadius: BorderRadius.circular(
          radius == GmRadius.pill ? (height ?? 44) / 2 : radius),
      tint: gm.glass,
      edge: gm.glassEdge,
      blur: 24,
      shadow: shadow ?? gm.shadow1,
      child: SizedBox(
        height: height,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Volcán de marca con la tinta que vive en noche (el del asset es vino
/// fijo, ilegible sobre el cristal oscuro).
class MapVolcanoGlyph extends StatelessWidget {
  final double size;
  const MapVolcanoGlyph({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    final ink = GmColors.of(context).isDark ? '#F3EEE4' : '#2A0E14';
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
      '<circle cx="10.6" cy="5.4" r="1.8" fill="#C9A96B"/>'
      '<circle cx="13.6" cy="3.9" r="2.2" fill="#C9A96B"/>'
      '<path d="M2 21.5L8.7 9.9A2 2 0 0110.4 8.9h3.2a2 2 0 011.7 1L22 21.5z" fill="$ink"/>'
      '<path d="M9.4 9.7L11 12l1-1.3 1.2 1.7 1.5-2.6" fill="none" stroke="#E0603A" '
      'stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>',
      width: size,
      height: size,
      excludeFromSemantics: true,
    );
  }
}

/// Glifo del tipo (o los cubiertos neutros si no tiene tipo).
class MapTypeGlyph extends StatelessWidget {
  final ListThemeKind? kind;
  final double size;
  final Color? color;
  const MapTypeGlyph(this.kind, {super.key, this.size = 20, this.color});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final theme = kind == null ? null : kListThemes[kind];
    return ListThemeGlyph(
      theme?.glyph ?? ListGlyph.restaurante,
      size: size,
      color: color ?? theme?.ink(gm.isDark) ?? gm.label2,
    );
  }
}

/// Buscador de cristal «Buscar en el mapa».
class MapSearchCapsule extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final FocusNode? focusNode;

  const MapSearchCapsule({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: 'mapa-search-field',
      textField: true,
      child: MapGlassCapsule(
        height: 48,
        padding: const EdgeInsets.only(left: 15, right: 6),
        child: Row(
          children: [
            GmIcon(GmIcons.search, size: 18, color: gm.label2),
            const SizedBox(width: 9),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                style: GmText.body17(color: gm.label),
                cursorColor: gm.accent,
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'Buscar en el mapa',
                  hintStyle: GmText.body17(color: gm.label2),
                ),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, v, __) => v.text.isEmpty
                  ? const SizedBox(width: 10)
                  : Semantics(
                      identifier: 'mapa-search-clear',
                      label: 'Borrar búsqueda',
                      button: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onClear,
                        child: SizedBox(
                          width: 36,
                          height: 44,
                          child: Center(
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                  color: gm.fill, shape: BoxShape.circle),
                              child: Center(
                                child: GmIcon(GmIcons.xSmall,
                                    size: 9, color: gm.label2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip de isla «Tenerife ⌄» con el volcán (abre el selector de isla).
class MapIslandChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const MapIslandChip({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: 'mapa-island-chip',
      button: true,
      label: 'Cambiar de isla, ahora $label',
      excludeSemantics: true,
      child: GmPressable(
        onTap: onTap,
        pressedScale: 0.95,
        child: MapGlassCapsule(
          height: 48,
          padding: const EdgeInsets.only(left: 10, right: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MapVolcanoGlyph(size: 22),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: gm.glassInk,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GmIcon(GmIcons.chevronDown, size: 16, color: gm.glassInk),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón redondo de cristal (44, o 56 en modo coche).
class MapRoundButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;
  final String? identifier;
  final double size;
  final double iconSize;

  const MapRoundButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.identifier,
    this.size = 44,
    this.iconSize = 19,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: identifier,
      label: label,
      button: true,
      excludeSemantics: true,
      child: GmPressable(
        onTap: onTap,
        pressedScale: 0.9,
        child: SizedBox(
          width: size,
          height: size,
          child: GmGlass(
            borderRadius: BorderRadius.circular(size / 2),
            tint: gm.glass,
            edge: gm.glassEdge,
            blur: 20,
            shadow: gm.shadow1,
            child:
                Center(child: GmIcon(icon, size: iconSize, color: gm.glassInk)),
          ),
        ),
      ),
    );
  }
}

/// Chip de filtro sobre el mapa (34 visibles, 44 de toque). Activo:
/// `accentSoft` sobre tarjeta, texto `accent` y aspa.
class MapFilterChip extends StatelessWidget {
  final String label;
  final Widget? leading;
  final bool active;
  final VoidCallback onTap;
  final String identifier;

  const MapFilterChip({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    required this.identifier,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 6)],
        Text(
          label,
          maxLines: 1,
          style: TextStyle(
            fontSize: 14,
            height: 1.2,
            fontWeight: FontWeight.w600,
            color: active ? gm.accent : gm.glassInk,
          ),
        ),
        if (active) ...[
          const SizedBox(width: 6),
          GmIcon(GmIcons.xSmall, size: 11, color: gm.accent),
        ],
      ],
    );
    final pad = EdgeInsets.only(left: leading != null ? 8 : 12, right: 12);
    return Semantics(
      identifier: identifier,
      button: true,
      selected: active,
      label: active ? 'Quitar filtro $label' : 'Filtrar por $label',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          // 34 visibles, 44 de toque.
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: active
              ? Container(
                  height: 34,
                  padding: pad,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(gm.accentSoft, gm.card),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: const Color(0x470085C4)),
                    boxShadow: gm.shadow1,
                  ),
                  child: content,
                )
              : MapGlassCapsule(
                  height: 34,
                  padding: pad,
                  child: Center(widthFactor: 1, child: content),
                ),
        ),
      ),
    );
  }
}

/// Fila de chips: «Abierto ahora» + tipos con glifo (activos primero), con
/// fundido de 28 a la derecha. [skeleton] = cápsulas vacías (cargando).
class MapChipRow extends StatelessWidget {
  final bool openNow;
  final List<MapTypeChip> types;
  final Set<String> activeTypes;
  final VoidCallback onToggleOpen;
  final ValueChanged<String> onToggleType;
  final bool skeleton;

  const MapChipRow({
    super.key,
    required this.openNow,
    required this.types,
    required this.activeTypes,
    required this.onToggleOpen,
    required this.onToggleType,
    this.skeleton = false,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    if (skeleton) {
      return ExcludeSemantics(
        child: SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
                horizontal: GmSpace.gutter, vertical: 5),
            children: [
              for (final w in const [132.0, 186.0, 200.0, 110.0])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: MapGlassCapsule(
                    height: 34,
                    shadow: const [],
                    child: SizedBox(width: w),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    final openChip = MapFilterChip(
      identifier: 'mapa-pill-abierto',
      label: 'Abierto ahora',
      active: openNow,
      leading: GmLiveDot(color: gm.green),
      onTap: onToggleOpen,
    );
    final typeChips = [
      for (final t in types)
        MapFilterChip(
          identifier: 'mapa-pill-${t.id}',
          label: t.label,
          active: activeTypes.contains(t.id),
          leading: MapTypeGlyph(t.kind,
              size: 20, color: activeTypes.contains(t.id) ? gm.accent : null),
          onTap: () => onToggleType(t.id),
        )
    ];
    final active = [
      if (openNow) openChip,
      ...[
        for (var i = 0; i < types.length; i++)
          if (activeTypes.contains(types[i].id)) typeChips[i]
      ],
    ];
    final rest = [
      if (!openNow) openChip,
      ...[
        for (var i = 0; i < types.length; i++)
          if (!activeTypes.contains(types[i].id)) typeChips[i]
      ],
    ];
    final chips = [...active, ...rest];
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (r) => LinearGradient(
          colors: const [Colors.black, Colors.black, Colors.transparent],
          stops: [0, (r.width - 28) / r.width, 1],
        ).createShader(r),
        child: SizedBox(
          height: 44 + 12,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.fromLTRB(GmSpace.gutter, 0, 40, 12),
            itemCount: chips.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => chips[i],
          ),
        ),
      ),
    );
  }
}

/// Píldora de cristal pequeña (accesorio «16 abiertos de 37 en esta zona»,
/// «19 sitios a menos de 3 km»).
class MapInfoPill extends StatelessWidget {
  final String text;
  final bool dot;
  final double height;
  final double fontSize;
  final String? identifier;

  const MapInfoPill({
    super.key,
    required this.text,
    this.dot = false,
    this.height = 32,
    this.fontSize = 13,
    this.identifier,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: identifier,
      container: true,
      child: MapGlassCapsule(
        height: height,
        padding: EdgeInsets.symmetric(horizontal: height > 40 ? 16 : 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot) ...[
              GmLiveDot(color: gm.green, size: height > 40 ? 9 : 7),
              SizedBox(width: height > 40 ? 8 : 6),
            ],
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: gm.glassInk,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cápsula «Cargando sitios de Tenerife…» con indicador.
class MapLoadingCapsule extends StatelessWidget {
  final String text;
  const MapLoadingCapsule({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final reduced = GmMotion.reduced(context);
    return Semantics(
      identifier: 'mapa-loading',
      liveRegion: true,
      label: text,
      excludeSemantics: true,
      child: MapGlassCapsule(
        height: 44,
        padding: const EdgeInsets.only(left: 14, right: 18),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                // Con «reducir movimiento», arco quieto.
                value: reduced ? 0.3 : null,
                color: gm.accent,
                backgroundColor: gm.sep,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: gm.glassInk,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Aviso de una línea sin ubicación: «Sin ubicación, el mapa no sabe qué
/// te queda cerca.» + «Activar».
class MapNoLocationBanner extends StatelessWidget {
  final VoidCallback onActivate;
  const MapNoLocationBanner({super.key, required this.onActivate});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: 'mapa-noloc-banner',
      container: true,
      child: MapGlassCapsule(
        radius: 22,
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: gm.warnSoft,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(
                child: SvgPicture.string(kMapLocateIcon,
                    width: 16,
                    height: 16,
                    theme: SvgTheme(currentColor: gm.warnText),
                    excludeFromSemantics: true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Sin ubicación, el mapa no sabe qué te queda cerca.',
                style: TextStyle(
                  fontSize: 14,
                  height: 19 / 14,
                  fontWeight: FontWeight.w500,
                  color: gm.glassInk,
                ),
              ),
            ),
            const SizedBox(width: 10),
            GmCapsuleButton(
              identifier: 'mapa-noloc-activate',
              label: 'Activar',
              height: 36,
              fontSize: 15,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              onTap: onActivate,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta flotante de estado (error, vacío con filtros): arte, título,
/// texto y botones, centrada.
class MapStateCard extends StatelessWidget {
  final Widget art;
  final String title;
  final String text;
  final List<Widget> actions;
  final bool alert;
  final String? identifier;

  const MapStateCard({
    super.key,
    required this.art,
    required this.title,
    required this.text,
    this.actions = const [],
    this.alert = false,
    this.identifier,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: identifier,
      liveRegion: alert,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: gm.card,
          borderRadius: BorderRadius.circular(GmRadius.card),
          boxShadow: gm.shadow2,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              art,
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GmText.poster(color: gm.label),
              ),
              const SizedBox(height: 6),
              Text(
                text,
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 15, height: 21 / 15, color: gm.label2),
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: actions,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Loseta del tipo para estados (tinte + glifo, 64 r20).
class MapTypeTile extends StatelessWidget {
  final ListThemeKind? kind;
  final double size;
  final double glyph;
  final double radius;
  const MapTypeTile(this.kind,
      {super.key, this.size = 64, this.glyph = 40, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final theme = kListThemes[kind ?? ListThemeKind.restaurante]!;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.tint(gm.isDark),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(child: MapTypeGlyph(kind, size: glyph)),
    );
  }
}

/// Control segmentado de cristal Lista / Mapa (44, segmentos de 38).
class MapSegmented extends StatelessWidget {
  final bool listSelected;
  final ValueChanged<bool> onChanged;
  const MapSegmented(
      {super.key, required this.listSelected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    Widget seg(bool isList) {
      final on = listSelected == isList;
      return Semantics(
        identifier: isList ? 'mapa-nearby-list' : 'mapa-nearby-map',
        button: true,
        selected: on,
        label: isList ? 'Lista' : 'Mapa',
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (on) return;
            HapticFeedback.selectionClick();
            onChanged(isList);
          },
          child: AnimatedContainer(
            duration:
                Duration(milliseconds: GmMotion.reduced(context) ? 0 : 220),
            width: 42,
            height: 38,
            decoration: BoxDecoration(
              color: on ? gm.card : Colors.transparent,
              borderRadius: BorderRadius.circular(19),
              boxShadow: on
                  ? const [
                      BoxShadow(
                          color: Color(0x1F000000),
                          offset: Offset(0, 1),
                          blurRadius: 3)
                    ]
                  : null,
            ),
            child: Center(
              child: GmIcon(isList ? GmIcons.list : GmIcons.map,
                  size: 18, color: on ? gm.label : gm.label2),
            ),
          ),
        ),
      );
    }

    return MapGlassCapsule(
      height: 44,
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [seg(true), seg(false)],
      ),
    );
  }
}

/// Bloque de esqueleto (relleno `fill`, quieto).
class MapSkeleton extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const MapSkeleton(
      {super.key, this.width, required this.height, this.radius = 6});

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
