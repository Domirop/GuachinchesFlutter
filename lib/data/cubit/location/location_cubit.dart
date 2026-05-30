import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'location_state.dart';

class LocationCubit extends Cubit<LocationState> {
  LocationCubit() : super(LocationInitial());

  /// Llamado al arranque y cuando el usuario tap el banner / botón "Activar".
  /// Puede disparar el modal nativo de iOS si el permiso aún no fue rechazado
  /// permanentemente.
  Future<void> requestLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(LocationServiceDisabled());
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      // `denied` puede pedirse de nuevo. `deniedForever` no — iOS ignora
      // el request y devuelve el mismo valor sin mostrar modal.
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        emit(LocationPermanentlyDenied());
        return;
      }

      final granted = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;

      if (!granted) {
        emit(LocationDenied());
        return;
      }

      await _fetchAndEmitLocation();
    } catch (e) {
      emit(LocationDenied());
    }
  }

  /// Llamado al resume de la app. Nunca muestra modal del sistema. Si el
  /// usuario activó el permiso en Ajustes y volvió, recogemos el cambio.
  Future<void> checkLocationSilently() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (state is! LocationServiceDisabled) {
          emit(LocationServiceDisabled());
        }
        return;
      }

      final permission = await Geolocator.checkPermission();
      final granted = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;

      if (granted && state is! LocationLoaded && state is! LocationLoading) {
        await _fetchAndEmitLocation();
      } else if (!granted && state is LocationLoaded) {
        emit(permission == LocationPermission.deniedForever
            ? LocationPermanentlyDenied()
            : LocationDenied());
      }
    } catch (_) {}
  }

  Future<void> _fetchAndEmitLocation() async {
    emit(LocationLoading());

    // ── Attempt 1: getCurrentPosition ─────────────────────────────────────
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).timeout(const Duration(seconds: 15));
    } catch (_) {
      position = null;
    }

    // ── Attempt 2: position stream ────────────────────────────────────────
    if (position == null) {
      try {
        position = await Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
          ),
        ).first.timeout(const Duration(seconds: 20));
      } catch (_) {
        emit(LocationUnavailable());
        return;
      }
    }

    emit(LocationLoaded(latitude: position.latitude, longitude: position.longitude));
  }
}
