import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/data/cubit/location/location_cubit.dart';
import 'package:guachinches/data/cubit/location/location_state.dart';
import 'package:guachinches/ui/pages/location_denied/location_denied_screen.dart';

/// Acción correcta al tap en cualquier CTA "Activar ubicación" según el
/// sub-tipo de [LocationDenied].
///
///  - `LocationDenied` base → `requestLocation()` (modal nativo iOS).
///  - `LocationPermanentlyDenied` → push [LocationDeniedScreen].
///  - `LocationServiceDisabled` → push [LocationDeniedScreen].
///  - Cualquier otro estado → llamar `requestLocation()` defensivamente
///    (cubre `LocationInitial` por si una pantalla profunda usa el helper
///    antes de que el cubit haya arrancado).
///
/// Comparte la lógica entre [LocationPromptBanner] y [CercaAhoraScreen] para
/// que el comportamiento sea idéntico en todas partes.
Future<void> handleLocationPromptTap(BuildContext context) async {
  final cubit = context.read<LocationCubit>();
  final state = cubit.state;
  if (state is LocationPermanentlyDenied ||
      state is LocationServiceDisabled) {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LocationDeniedScreen()),
    );
    if (context.mounted) {
      await cubit.checkLocationSilently();
    }
    return;
  }
  await cubit.requestLocation();
}
