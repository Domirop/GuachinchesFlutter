import 'package:flutter/material.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'maintenance-screen-root',
      child: Scaffold(
        body: const Center(
          child: Text('Estamos haciendo mejoras, volvemos pronto.'),
        ),
      ),
    );
  }
}
