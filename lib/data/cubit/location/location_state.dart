abstract class LocationState {}

class LocationInitial extends LocationState {}

class LocationLoading extends LocationState {}

class LocationLoaded extends LocationState {
  final double latitude;
  final double longitude;
  LocationLoaded({required this.latitude, required this.longitude});
}

/// The user explicitly denied (or revoked) the location permission.
/// → Show the "Activar" banner.
class LocationDenied extends LocationState {}

/// Permission is granted but we could not obtain a GPS fix.
/// → Hide the section silently (no misleading banner).
class LocationUnavailable extends LocationState {}
