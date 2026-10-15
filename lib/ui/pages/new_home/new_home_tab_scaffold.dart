import 'dart:math' as math;
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/cubit/menu/menu_cubit.dart';
import 'package:guachinches/l10n/app_localizations.dart';
import 'package:guachinches/ui/components/offline_banner.dart';
import 'package:guachinches/ui/pages/discover/discover_screen.dart';
import 'package:guachinches/ui/pages/new_home/new_home_screen.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_tab_accessory.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// Tabs de la app: EXPLORA · LISTAS · MAPA · VISITAS · PERFIL.
///
/// Barra de pestañas flotante de cristal (rediseño iOS 27). El contenido
/// scrollea por debajo (`extendBody: true`); en la home la barra se minimiza
/// al bajar y muestra el accesorio del momento (ver [_FloatingGlassNavBar]).
class NewHomeTabScaffold extends StatefulWidget {
  /// Lista de 5 widgets para los slots EXPLORA, LISTAS, MAPA, VIDEOS, PERFIL.
  /// Si es null, se usan defaults (NewHomeScreen + placeholders).
  final List<Widget>? screens;
  final int initialIndex;

  const NewHomeTabScaffold({
    super.key,
    this.screens,
    this.initialIndex = 0,
  });

  @override
  State<NewHomeTabScaffold> createState() => _NewHomeTabScaffoldState();
}

class _NewHomeTabScaffoldState extends State<NewHomeTabScaffold> {
  late int _index;

  /// Barra minimizada (solo en la pestaña Explora, al bajar por la home).
  bool _minimized = false;

  /// Umbral: por debajo del hero + primera sección. Arriba de [_expandAt]
  /// siempre se ve la barra completa.
  static const double _minimizeAfter = 620;
  static const double _expandAt = 420;

  bool _onScroll(ScrollNotification n) {
    if (_index != 0 || n.metrics.axis != Axis.vertical) return false;
    if (n.depth != 0) return false;
    if (n is ScrollUpdateNotification && n.scrollDelta != null) {
      final px = n.metrics.pixels;
      final d = n.scrollDelta!;
      if (!_minimized &&
          d > 2 &&
          px > _minimizeAfter &&
          gmTabAccessory.value != null) {
        setState(() => _minimized = true);
      } else if (_minimized && (d < -6 || px < _expandAt)) {
        setState(() => _minimized = false);
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, 4);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MenuCubit>().updateSelectedIndex(_index);
    });
  }

  void _onTap(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _index = i;
      _minimized = false;
    });
    context.read<MenuCubit>().updateSelectedIndex(i);
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final l10n = AppL10n.of(context);
    final gm = GmColors.of(context);
    final screens = widget.screens ??
        const [
          NewHomeScreen(),
          _PlaceholderTab('Listas'),
          _PlaceholderTab('Mapa'),
          // Tab "Visitas" = todas las visitas (vídeos de Jonay y Joana).
          // No es la lista del usuario — para eso existe `VisitasScreen` con
          // `UserVisitsCubit`, pero no es lo que esta tab debe enseñar.
          // `DiscoverScreen` consume `VisitsCubit.loadVisits()` →
          // `getAllVisits()` (endpoint público publicado).
          DiscoverScreen(),
          _PlaceholderTab('Perfil'),
        ];

    return Scaffold(
      backgroundColor: _index == 0 ? gm.canvas : brand.base,
      // El contenido se extiende POR DEBAJO de la cápsula flotante: el blur
      // del glass necesita contenido detrás para leerse como iOS 26.
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: IndexedStack(
                index: _index,
                children: [
                  for (var i = 0; i < screens.length; i++)
                    // Las animaciones en bucle de la home (nubes, punto
                    // vivo) se paran cuando su pestaña no está visible.
                    i == 0
                        ? TickerMode(enabled: _index == 0, child: screens[i])
                        : screens[i],
                ],
              ),
            ),
          ),
          // «Sin conexión» flota bajo la barra de estado, sin mover nada.
          Positioned(
            left: 16,
            right: 16,
            top: MediaQuery.paddingOf(context).top + 6,
            child: const OfflineBanner(),
          ),
        ],
      ),
      bottomNavigationBar: ValueListenableBuilder<GmTabAccessoryData?>(
        valueListenable: gmTabAccessory,
        builder: (_, __, ___) => _FloatingGlassNavBar(
          index: _index,
          onTap: _onTap,
          minimized: _minimized && _index == 0,
          showEdgeFade: _index == 0,
          onExpand: () => setState(() => _minimized = false),
          items: [
            _NavItem('tab-explora', l10n.tabExplora, GmIcons.tabExplora,
                GmIcons.tabExploraOn),
            _NavItem('tab-listas', l10n.tabListas, GmIcons.tabListas,
                GmIcons.tabListas),
            _NavItem(
                'tab-mapa', l10n.tabMapa, GmIcons.tabMapa, GmIcons.tabMapa),
            _NavItem('tab-visitas', l10n.tabVisitas, GmIcons.tabVisitas,
                GmIcons.tabVisitas),
            _NavItem('tab-perfil', l10n.tabPerfil, GmIcons.tabPerfil,
                GmIcons.tabPerfil),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final String identifier;
  final String label;
  final String icon;
  final String activeIcon;
  const _NavItem(this.identifier, this.label, this.icon, this.activeIcon);
}

/// Barra de pestañas flotante de cristal (rediseño iOS 27, tablero
/// InicioCompleto §12 + InicioScroll):
/// - Cápsula de cristal (desenfoque 30 + velo + filo 1 px + brillo) a 16 de
///   los bordes, 5 pestañas con icono 25 + etiqueta 10/12.
/// - La pestaña activa lleva una píldora teñida que se desliza y se asienta
///   con estirar-y-encoger (820 ms, muelle); el icono da un saltito.
/// - Arrastrar el dedo por la barra mueve la píldora en tiempo real y al
///   soltar engancha al tab más cercano.
/// - En la home, al bajar, la barra se minimiza a un círculo y aparece el
///   accesorio del momento ([gmTabAccessory]); al subir vuelve a crecer.
class _FloatingGlassNavBar extends StatefulWidget {
  final int index;
  final ValueChanged<int> onTap;
  final List<_NavItem> items;
  final bool minimized;
  final VoidCallback onExpand;
  final bool showEdgeFade;

  const _FloatingGlassNavBar({
    required this.index,
    required this.onTap,
    required this.items,
    required this.minimized,
    required this.onExpand,
    required this.showEdgeFade,
  });

  @override
  State<_FloatingGlassNavBar> createState() => _FloatingGlassNavBarState();
}

class _FloatingGlassNavBarState extends State<_FloatingGlassNavBar>
    with TickerProviderStateMixin {
  /// X local del dedo durante el arrastre (null = sin arrastrar).
  double? _dragX;

  /// Ancho interno de la cápsula (de LayoutBuilder), para mapear x → slot.
  double _innerW = 0;
  int _lastSlot = -1;

  late final AnimationController _squash =
      AnimationController(vsync: this, duration: GmMotion.tabSquash, value: 1);
  late final AnimationController _hop = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800), value: 1);
  late final AnimationController _min = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
      value: widget.minimized ? 1 : 0);

  @override
  void didUpdateWidget(covariant _FloatingGlassNavBar old) {
    super.didUpdateWidget(old);
    final reduced = GmMotion.reduced(context);
    if (old.index != widget.index && !reduced) {
      _squash.forward(from: 0);
      _hop.forward(from: 0);
    }
    if (old.minimized != widget.minimized) {
      if (reduced) {
        _min.value = widget.minimized ? 1 : 0;
      } else {
        widget.minimized ? _min.forward() : _min.reverse();
      }
    }
  }

  @override
  void dispose() {
    _squash.dispose();
    _hop.dispose();
    _min.dispose();
    super.dispose();
  }

  int _slotAt(double x) {
    final n = widget.items.length;
    if (_innerW <= 0) return widget.index;
    return (x / (_innerW / n)).floor().clamp(0, n - 1);
  }

  void _onDragStart(DragStartDetails d) {
    final x = d.localPosition.dx.clamp(0.0, _innerW);
    _lastSlot = _slotAt(x);
    setState(() => _dragX = x);
  }

  void _onDragUpdate(DragUpdateDetails d) {
    final x = d.localPosition.dx.clamp(0.0, _innerW);
    final slot = _slotAt(x);
    if (slot != _lastSlot) {
      HapticFeedback.selectionClick();
      _lastSlot = slot;
    }
    setState(() => _dragX = x);
  }

  void _onDragEnd() {
    if (_dragX != null) widget.onTap(_slotAt(_dragX!));
    setState(() => _dragX = null);
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final bottomPad = bottomInset > 0 ? math.max(bottomInset - 6, 12.0) : 12.0;

    // Barra de alto fijo (como la de iOS): las etiquetas escalan hasta 1,2×.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Fundido del borde inferior bajo la barra (el contenido se apaga
          // antes de pasar por debajo del cristal).
          if (widget.showEdgeFade)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 132,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [gm.edgeFade0, gm.edgeFade1],
                      stops: const [0, 0.62],
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad),
            child: SizedBox(
              height: 64,
              child: LayoutBuilder(
                builder: (context, c) => AnimatedBuilder(
                  animation: _min,
                  builder: (context, _) => _buildMorph(context, gm, c.maxWidth),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMorph(BuildContext context, GmColors gm, double fullW) {
    final t = GmMotion.settle.transform(_min.value);
    final barW = lerpDouble(fullW, 56, t)!;
    final barH = lerpDouble(64, 56, t)!;
    final accessory = gmTabAccessory.value;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Accesorio (solo minimizada).
        if (_min.value > 0 && accessory != null)
          Positioned(
            left: 66,
            right: 0,
            top: 4,
            height: 56,
            child: Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(-40 * (1 - t), 0),
                child: _AccessoryCapsule(data: accessory),
              ),
            ),
          ),
        Positioned(
          left: 0,
          top: (64 - barH) / 2,
          width: barW,
          height: barH,
          child: GmGlass(
            borderRadius: BorderRadius.circular(GmRadius.pill),
            tint: gm.glass,
            edge: gm.glassEdge,
            blur: 30,
            shadow: gm.shadow2,
            child: _min.value < 0.5
                ? Opacity(
                    opacity: (1 - _min.value * 2).clamp(0.0, 1.0),
                    child: _buildTabs(context, gm, fullW),
                  )
                : Opacity(
                    opacity: ((_min.value - 0.5) * 2).clamp(0.0, 1.0),
                    child: _buildCollapsedButton(gm),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsedButton(GmColors gm) {
    final item = widget.items[widget.index];
    return Semantics(
      button: true,
      label: '${item.label} (mostrar pestañas)',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onExpand,
        child: Center(
          child: GmIcon(item.activeIcon, size: 26, color: gm.accent),
        ),
      ),
    );
  }

  Widget _buildTabs(BuildContext context, GmColors gm, double fullW) {
    final n = widget.items.length;
    final innerW = fullW - 8; // padding 4 por lado
    _innerW = innerW;
    final slotW = innerW / n;
    final dragging = _dragX != null;
    final effIndex = dragging ? _slotAt(_dragX!) : widget.index;

    final pill = AnimatedBuilder(
      animation: _squash,
      builder: (_, child) {
        final k = _squash.value;
        final sx = gmKeyframes(k,
            const [(0, 0.8), (0.3, 1.18), (0.52, 0.94), (0.72, 1.03), (1, 1)],
            curve: GmMotion.spring);
        final sy = gmKeyframes(k,
            const [(0, 0.8), (0.3, 0.84), (0.52, 1.06), (0.72, 0.98), (1, 1)],
            curve: GmMotion.spring);
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(sx, sy, 1),
          child: child,
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: gm.accentSoft,
          borderRadius: BorderRadius.circular(GmRadius.pill),
          border: Border.all(color: const Color(0x2E0085C4), width: 0.5),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(4),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: _onDragStart,
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: (_) => _onDragEnd(),
        child: Stack(
          children: [
            if (dragging)
              Positioned(
                left: (_dragX! - slotW / 2).clamp(0.0, innerW - slotW),
                top: 0,
                bottom: 0,
                width: slotW,
                child: pill,
              )
            else
              AnimatedPositioned(
                duration:
                    Duration(milliseconds: GmMotion.reduced(context) ? 0 : 420),
                curve: GmMotion.settle,
                left: widget.index * slotW,
                top: 0,
                bottom: 0,
                width: slotW,
                child: pill,
              ),
            Row(
              children: [
                for (var i = 0; i < n; i++)
                  Expanded(
                    child: _NavButton(
                      item: widget.items[i],
                      selected: i == effIndex,
                      hop: i == widget.index ? _hop : null,
                      onTap: () => widget.onTap(i),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessoryCapsule extends StatelessWidget {
  final GmTabAccessoryData data;
  const _AccessoryCapsule({required this.data});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      button: true,
      label: '${data.eyebrow}. ${data.title}',
      excludeSemantics: true,
      child: GmPressable(
        onTap: data.onTap,
        pressedScale: 0.97,
        child: GmGlass(
          borderRadius: BorderRadius.circular(GmRadius.pill),
          tint: gm.glass,
          edge: gm.glassEdge,
          blur: 30,
          shadow: gm.shadow2,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
            child: Row(
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: data.photoUrl != null && data.photoUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: data.photoUrl!,
                            fit: BoxFit.cover,
                            memCacheWidth: 120,
                            placeholder: (_, __) => ColoredBox(color: gm.fill),
                            errorWidget: (_, __, ___) =>
                                ColoredBox(color: gm.fill),
                          )
                        : ColoredBox(color: gm.fill),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const GmLiveDot(),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              data.eyebrow,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GmText.chip(color: gm.greenText),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        data.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            GmText.body(color: gm.glassInk, w: FontWeight.w600)
                                .copyWith(letterSpacing: -0.2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Opacity(
                  opacity: 0.5,
                  child: GmIcon(GmIcons.chevronRight,
                      size: 14, color: gm.glassInk),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final AnimationController? hop;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
    this.hop,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final color = selected ? gm.accent : gm.glassInk;
    Widget icon =
        GmIcon(selected ? item.activeIcon : item.icon, size: 25, color: color);
    if (hop != null) {
      icon = AnimatedBuilder(
        animation: hop!,
        child: icon,
        builder: (_, child) {
          // iconhop: 700 ms con 100 ms de retardo (del total de 800).
          final k = ((hop!.value * 800 - 100) / 700).clamp(0.0, 1.0);
          final dy = gmKeyframes(
              k, const [(0, 0), (0.35, -5), (0.65, 1), (1, 0)],
              curve: GmMotion.spring);
          final sx = gmKeyframes(
              k, const [(0, 1), (0.35, 0.94), (0.65, 1.06), (1, 1)],
              curve: GmMotion.spring);
          final sy = gmKeyframes(
              k, const [(0, 1), (0.35, 1.08), (0.65, 0.94), (1, 1)],
              curve: GmMotion.spring);
          return Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.translationValues(0, dy, 0)
              ..multiply(Matrix4.diagonal3Values(sx, sy, 1)),
            child: child,
          );
        },
      );
    }
    return Semantics(
      identifier: item.identifier,
      label: item.label,
      button: true,
      selected: selected,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(height: 2),
              Text(
                item.label,
                maxLines: 1,
                style: GmText.tab(
                  color: color,
                  w: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String name;
  const _PlaceholderTab(this.name);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.brand.base,
      body: Center(
        child: Text(
          name,
          style: TextStyle(
            color: context.brand.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
