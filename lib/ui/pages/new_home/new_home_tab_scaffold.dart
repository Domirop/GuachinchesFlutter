import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/cubit/menu/menu_cubit.dart';
import 'package:guachinches/l10n/app_localizations.dart';
import 'package:guachinches/ui/components/offline_banner.dart';
import 'package:guachinches/ui/pages/discover/discover_screen.dart';
import 'package:guachinches/ui/pages/new_home/new_home_screen.dart';

/// Tabs de la app: EXPLORA · LISTAS · MAPA · VISITAS · PERFIL.
/// Usa BottomNavigationBar clásico (Material) en la parte inferior.
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
  List<BottomNavigationBarItem> _buildItems(BuildContext context) {
    final l10n = AppL10n.of(context);
    return [
      BottomNavigationBarItem(
        icon: Semantics(
          identifier: 'tab-explora',
          child: const Icon(Icons.explore_outlined),
        ),
        activeIcon: Semantics(
          identifier: 'tab-explora',
          child: const Icon(Icons.explore),
        ),
        label: l10n.tabExplora,
      ),
      BottomNavigationBarItem(
        icon: Semantics(
          identifier: 'tab-listas',
          child: const Icon(Icons.list_rounded),
        ),
        label: l10n.tabListas,
      ),
      BottomNavigationBarItem(
        icon: Semantics(
          identifier: 'tab-mapa',
          child: const Icon(Icons.map_outlined),
        ),
        activeIcon: Semantics(
          identifier: 'tab-mapa',
          child: const Icon(Icons.map_rounded),
        ),
        label: l10n.tabMapa,
      ),
      BottomNavigationBarItem(
        icon: Semantics(
          identifier: 'tab-visitas',
          child: const Icon(Icons.movie_outlined),
        ),
        activeIcon: Semantics(
          identifier: 'tab-visitas',
          child: const Icon(Icons.movie_rounded),
        ),
        label: l10n.tabVisitas,
      ),
      BottomNavigationBarItem(
        icon: Semantics(
          identifier: 'tab-perfil',
          child: const Icon(Icons.person_outline_rounded),
        ),
        activeIcon: Semantics(
          identifier: 'tab-perfil',
          child: const Icon(Icons.person_rounded),
        ),
        label: l10n.tabPerfil,
      ),
    ];
  }

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
    setState(() => _index = i);
    context.read<MenuCubit>().updateSelectedIndex(i);
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _onTap,
        items: _buildItems(context),
        type: BottomNavigationBarType.fixed,
        backgroundColor: brand.surface,
        selectedItemColor: const Color(0xFF0085C4),
        unselectedItemColor: brand.textMuted,
        showUnselectedLabels: true,
        selectedFontSize: 11,
        unselectedFontSize: 11,
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
