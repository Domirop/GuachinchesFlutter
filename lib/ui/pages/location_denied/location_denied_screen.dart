import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/cubit/location/location_cubit.dart';
import 'package:guachinches/data/cubit/location/location_state.dart';

/// Pantalla de instrucciones para reactivar la ubicación cuando el modal
/// nativo ya no se puede mostrar (`LocationPermanentlyDenied`) o el servicio
/// está apagado a nivel del dispositivo (`LocationServiceDisabled`).
///
/// Diseño:
/// - Header hero con icono grande + título claro.
/// - Lista de pasos numerados en cards con iconos del sistema.
/// - CTA primario "Abrir Ajustes" que lanza `Geolocator.openAppSettings()`
///   (o `openLocationSettings()` cuando es servicio del sistema).
/// - CTA secundario "Más tarde" que vuelve.
/// - Al volver del background tras cambiar Ajustes, el `checkLocationSilently`
///   del cubit detecta el cambio y dispara `LocationLoaded` automáticamente.
class LocationDeniedScreen extends StatelessWidget {
  const LocationDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationCubit, LocationState>(
      builder: (context, state) {
        // Si por lo que sea volvemos aquí con permiso ya concedido, cerrar.
        if (state is LocationLoaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          });
        }
        final serviceDisabled = state is LocationServiceDisabled;
        return Scaffold(
          backgroundColor: context.brand.base,
          body: SafeArea(
            child: Semantics(
              identifier: 'location-denied-screen',
              child: Column(
                children: [
                  _Header(serviceDisabled: serviceDisabled),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: _StepsList(serviceDisabled: serviceDisabled),
                    ),
                  ),
                  _Actions(serviceDisabled: serviceDisabled),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final bool serviceDisabled;
  const _Header({required this.serviceDisabled});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: Icon(Icons.close_rounded, color: context.brand.textPrimary),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.atlantico.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.atlantico,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  serviceDisabled
                      ? 'UBICACIÓN APAGADA'
                      : 'NECESITAMOS TU UBICACIÓN',
                  style: AppTextStyles.eyebrow(
                    size: 11,
                    color: AppColors.atlantico,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  serviceDisabled
                      ? 'Activa los Servicios de Ubicación'
                      : 'Permite el acceso a tu ubicación',
                  style: AppTextStyles.displayHero(
                    size: 28,
                    color: context.brand.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  serviceDisabled
                      ? 'Tu iPhone tiene los Servicios de Ubicación apagados. Actívalos en Ajustes para ver los restaurantes cerca de ti.'
                      : 'Para mostrarte los abiertos cerca de ti y calcular distancias, necesitamos acceso a tu ubicación. Sigue estos pasos en Ajustes:',
                  style: AppTextStyles.ui(
                    size: 14,
                    color: context.brand.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepsList extends StatelessWidget {
  final bool serviceDisabled;
  const _StepsList({required this.serviceDisabled});

  @override
  Widget build(BuildContext context) {
    final steps = serviceDisabled
        ? const [
            _Step(n: 1, label: 'Abre Ajustes', icon: Icons.settings_rounded),
            _Step(n: 2, label: 'Privacidad y seguridad', icon: Icons.shield_outlined),
            _Step(n: 3, label: 'Localización', icon: Icons.location_on_outlined),
            _Step(
              n: 4,
              label: 'Activa "Servicios de Localización"',
              icon: Icons.toggle_on_rounded,
            ),
          ]
        : const [
            _Step(n: 1, label: 'Abre Ajustes de la app', icon: Icons.settings_rounded),
            _Step(n: 2, label: 'Toca "Ubicación"', icon: Icons.location_on_outlined),
            _Step(
              n: 3,
              label: 'Selecciona "Al usar la app"',
              icon: Icons.check_circle_outline,
            ),
          ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final s in steps) ...[
          s,
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final int n;
  final String label;
  final IconData icon;

  const _Step({required this.n, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.brand.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.brand.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.atlantico.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$n',
              style: AppTextStyles.ui(
                size: 13,
                weight: FontWeight.w700,
                color: AppColors.atlantico,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.ui(
                size: 14,
                weight: FontWeight.w500,
                color: context.brand.textPrimary,
              ),
            ),
          ),
          Icon(icon, color: context.brand.textMuted, size: 20),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  final bool serviceDisabled;
  const _Actions({required this.serviceDisabled});

  Future<void> _open() async {
    // En iOS no hay diferencia funcional — ambos llevan a Ajustes. En
    // Android sí: `openLocationSettings` abre directo el toggle del sistema.
    if (Platform.isAndroid && serviceDisabled) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 8, 20, MediaQuery.of(context).viewPadding.bottom + 12),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: Semantics(
              identifier: 'location-denied-open-settings',
              button: true,
              child: ElevatedButton(
                onPressed: _open,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.atlantico,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: AppTextStyles.ui(
                    size: 15,
                    weight: FontWeight.w600,
                  ),
                ),
                child: const Text('Abrir Ajustes'),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              'Más tarde',
              style: AppTextStyles.ui(
                size: 14,
                weight: FontWeight.w500,
                color: context.brand.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
