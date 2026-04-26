import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'location_state.dart';

class LocationCubit extends Cubit<LocationState> {
  LocationCubit() : super(LocationInitial());

  /// Called once on app start. May show the system permission dialog.
  Future<void> requestLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(LocationDenied());
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
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

  /// Called every time the app resumes. Never shows any system dialog.
  Future<void> checkLocationSilently() async {
    try {
      final permission = await Geolocator.checkPermission();
      final granted = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;

      if (granted && state is! LocationLoaded && state is! LocationLoading) {
        await _fetchAndEmitLocation();
      } else if (!granted && state is LocationLoaded) {
        emit(LocationDenied());
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
