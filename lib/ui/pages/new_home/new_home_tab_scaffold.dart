import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_shapes.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/cubit/menu/menu_cubit.dart';
import 'package:guachinches/l10n/app_localizations.dart';
import 'package:guachinches/ui/components/offline_banner.dart';
import 'package:guachinches/ui/pages/discover/discover_screen.dart';
import 'package:guachinches/ui/pages/new_home/new_home_screen.dart';

/// Tabs de la app: EXPLORA · LISTAS · MAPA · VISITAS · PERFIL.
///
/// Bottom bar flotante estilo iOS 26 / Instagram: cápsula de cristal
/// despegada de los bordes, con el MISMO lenguaje glass que las cápsulas del
/// hero (isla/zona y temperatura): BackdropFilter blur 16 + `brand.glass` +
/// borde fino. El contenido scrollea por debajo (`extendBody: true`) y el tab
/// activo lleva resalte pill en atlántico.
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
    setState(() => _index = i);
    context.read<MenuCubit>().updateSelectedIndex(i);
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final l10n = AppL10n.of(context);
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
      backgroundColor: brand.base,
      // El contenido se extiende POR DEBAJO de la cápsula flotante: el blur
      // del glass necesita contenido detrás para leerse como iOS 26.
      extendBody: true,
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _FloatingGlassNavBar(
        index: _index,
        onTap: _onTap,
        items: [
          _NavItem('tab-explora', l10n.tabExplora,
              Icons.explore_outlined, Icons.explore),
          _NavItem('tab-listas', l10n.tabListas,
              Icons.list_rounded, Icons.list_rounded),
          _NavItem('tab-mapa', l10n.tabMapa,
              Icons.map_outlined, Icons.map_rounded),
          _NavItem('tab-visitas', l10n.tabVisitas,
              Icons.movie_outlined, Icons.movie_rounded),
          _NavItem('tab-perfil', l10n.tabPerfil,
              Icons.person_outline_rounded, Icons.person_rounded),
        ],
      ),
    );
  }
}

class _NavItem {
  final String identifier;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _NavItem(this.identifier, this.label, this.icon, this.activeIcon);
}

/// Cápsula de navegación flotante (liquid glass iOS 26/27): frost + sheen
/// especular + una **píldora que fluye**. Tap cambia de tab; **arrastrar** el
/// dedo por la barra hace que la píldora siga al dedo en tiempo real y, al
/// soltar, engancha al tab más cercano (muelle `Curves.easeOutBack`).
class _FloatingGlassNavBar extends StatefulWidget {
  final int index;
  final ValueChanged<int> onTap;
  final List<_NavItem> items;

  const _FloatingGlassNavBar({
    required this.index,
    required this.onTap,
    required this.items,
  });

  @override
  State<_FloatingGlassNavBar> createState() => _FloatingGlassNavBarState();
}

class _FloatingGlassNavBarState extends State<_FloatingGlassNavBar> {
  /// X local del dedo durante el arrastre (null = sin arrastrar).
  double? _dragX;

  /// Ancho interno de la cápsula (de LayoutBuilder), para mapear x → slot.
  double _innerW = 0;
  int _lastSlot = -1;

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
    final brand = context.brand;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: brand.glass,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                    color: Colors.white.withOpacity(isDark ? 0.18 : 0.4),
                    width: 0.8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: LayoutBuilder(
                builder: (context, c) {
                  _innerW = c.maxWidth;
                  final n = widget.items.length;
                  final slotW = c.maxWidth / n;
                  final dragging = _dragX != null;
                  final effIndex = dragging ? _slotAt(_dragX!) : widget.index;
                  final pillW = slotW - 12;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragStart: _onDragStart,
                    onHorizontalDragUpdate: _onDragUpdate,
                    onHorizontalDragEnd: (_) => _onDragEnd(),
                    child: Stack(
                      children: [
                        // Sheen especular del borde superior.
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white
                                        .withOpacity(isDark ? 0.10 : 0.22),
                                    Colors.white.withOpacity(0),
                                  ],
                                  stops: const [0.0, 0.6],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Píldora líquida: sigue al dedo al arrastrar; si no,
                        // se desliza con muelle al tab activo.
                        if (dragging)
                          Positioned(
                            left: (_dragX! - pillW / 2)
                                .clamp(6.0, c.maxWidth - pillW - 6),
                            top: 9,
                            bottom: 9,
                            width: pillW,
                            child: const _LiquidPill(),
                          )
                        else
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 420),
                            curve: Curves.easeOutBack,
                            left: widget.index * slotW + 6,
                            top: 9,
                            bottom: 9,
                            width: pillW,
                            child: const _LiquidPill(),
                          ),
                        // Iconos.
                        Row(
                          children: [
                            for (var i = 0; i < n; i++)
                              Expanded(
                                child: _NavButton(
                                  item: widget.items[i],
                                  selected: i == effIndex,
                                  onTap: () => widget.onTap(i),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Resalte líquido del tab activo: tinte atlántico + borde + glow suave.
class _LiquidPill extends StatelessWidget {
  const _LiquidPill();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.atlantico.withOpacity(0.18),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
            color: AppColors.atlantico.withOpacity(0.32), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: AppColors.atlantico.withOpacity(0.20),
            blurRadius: 10,
            spreadRadius: -2,
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Semantics(
      identifier: item.identifier,
      label: item.label,
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          // Rebote del icono al seleccionarse (muelle corto).
          child: AnimatedScale(
            scale: selected ? 1.12 : 1.0,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutBack,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: Icon(
                selected ? item.activeIcon : item.icon,
                key: ValueKey(selected),
                size: 26,
                color: selected ? AppColors.atlantico : brand.textPrimary,
              ),
            ),
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
