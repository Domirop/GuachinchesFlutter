import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/ui/pages/new_home/new_home_screen.dart';

/// Host de las 5 tabs de la nueva home.
/// Solo EXPLORA (index 0) carga NewHomeScreen.
/// El resto son placeholders hasta Fase 2.
class NewHomeTabScaffold extends StatefulWidget {
  const NewHomeTabScaffold({super.key});

  @override
  State<NewHomeTabScaffold> createState() => _NewHomeTabScaffoldState();
}

class _NewHomeTabScaffoldState extends State<NewHomeTabScaffold> {
  int _index = 0;

  static const _screens = [
    NewHomeScreen(),         // 0 — EXPLORA
    _PlaceholderTab('LISTAS'),    // 1
    _PlaceholderTab('BUSCAR'),    // 2
    _PlaceholderTab('GUARDADO'),  // 3
    _PlaceholderTab('PERFIL'),    // 4
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.brand.base,
      body: IndexedStack(
        index: _index,
        children: _screens,
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
