abstract class LocationState {}

class LocationInitial extends LocationState {}

class LocationLoading extends LocationState {}

class LocationLoaded extends LocationState {
  final double latitude;
  final double longitude;
  LocationLoaded({required this.latitude, required this.longitude});
}

/// El usuario denegó (o aún no concedió) el permiso de ubicación. Puede
/// volver a mostrarse el modal nativo del sistema.
///
/// Sub-tipos para distinguir la acción adecuada:
///   - [LocationDenied] base: aún no se pidió o se denegó una vez (iOS sigue
///     permitiendo mostrar el modal nativo otra vez).
///   - [LocationPermanentlyDenied]: el usuario rechazó "Don't allow" y iOS
///     no volverá a mostrar el modal — hay que llevarlo a Ajustes.
///   - [LocationServiceDisabled]: el servicio de ubicación del sistema está
///     apagado a nivel del dispositivo (Settings → Privacy → Location → Off).
///     `requestPermission` no puede arreglar esto: hay que enviar a Ajustes.
///
/// Importante: jerarquía por herencia para retrocompatibilidad. Los checks
/// existentes `state is LocationDenied` siguen funcionando para los tres
/// estados (todos son `LocationDenied`).
class LocationDenied extends LocationState {}

class LocationPermanentlyDenied extends LocationDenied {}

class LocationServiceDisabled extends LocationDenied {}

/// Permiso concedido pero no se pudo obtener fix de GPS.
/// → Ocultar la sección silenciosamente (sin banner engañoso).
class LocationUnavailable extends LocationState {}
