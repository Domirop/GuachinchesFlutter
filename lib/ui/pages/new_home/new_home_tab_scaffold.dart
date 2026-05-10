import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/cubit/menu/menu_cubit.dart';
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
  static const _items = <BottomNavigationBarItem>[
    BottomNavigationBarItem(
      icon: Icon(Icons.explore_outlined),
      activeIcon: Icon(Icons.explore),
      label: 'Explora',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.list_rounded),
      label: 'Listas',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.map_outlined),
      activeIcon: Icon(Icons.map_rounded),
      label: 'Mapa',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.movie_outlined),
      activeIcon: Icon(Icons.movie_rounded),
      label: 'Visitas',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline_rounded),
      activeIcon: Icon(Icons.person_rounded),
      label: 'Perfil',
    ),
  ];

  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, _items.length - 1);
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
          _PlaceholderTab('Visitas'),
          _PlaceholderTab('Perfil'),
        ];

    return Scaffold(
      backgroundColor: brand.base,
      body: IndexedStack(
        index: _index,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _onTap,
        items: _items,
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
