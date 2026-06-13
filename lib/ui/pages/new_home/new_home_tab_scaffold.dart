import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/config/app_colors.dart';
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

/// Cápsula de navegación flotante (glass). Mismo patrón visual que
/// `_GlassCapsule` del TopFilterBar: blur 16 + brand.glass + borde 0.6.
class _FloatingGlassNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final List<_NavItem> items;

  const _FloatingGlassNavBar({
    required this.index,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Padding(
        // En devices sin home-indicator (safe bottom = 0) el minimum ya aplica;
        // con indicator, la cápsula queda justo encima de él.
        padding: const EdgeInsets.only(top: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: brand.glass,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: brand.border, width: 0.6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: _NavButton(
                        item: items[i],
                        selected: i == index,
                        onTap: () => onTap(i),
                      ),
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: 44,
            width: selected ? 56 : 44,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.atlantico.withOpacity(0.16)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(
              selected ? item.activeIcon : item.icon,
              size: 26,
              // Inactivos en tinta (como Instagram): sobre el cristal, el gris
              // muted se perdía. El activo mantiene el acento atlántico.
              color: selected ? AppColors.atlantico : brand.textPrimary,
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
