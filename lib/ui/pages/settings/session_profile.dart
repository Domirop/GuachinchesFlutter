import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/ui/pages/settings/perfil_logic.dart';
import 'package:guachinches/services/app_storage.dart';

/// Lo que el móvil sabe de la sesión sin preguntar al backend.
///
/// Desde backend 042, `GET /user/:id` devuelve `email` y `apellidos` vacíos
/// (fuga de datos personales sin auth). La tarjeta de identidad del Perfil
/// pinta el email y el proveedor que se guardaron al iniciar sesión
/// (migration-mobile/011), y el nombre que se vio la última vez (para que la
/// tarjeta no quede vacía si el perfil no carga).
class SessionProfile {
  final String? email;
  final PerfilProvider? provider;
  final String? name;

  const SessionProfile({this.email, this.provider, this.name});

  static const empty = SessionProfile();
}

/// Lectura/escritura de [SessionProfile] en `flutter_secure_storage`.
class SessionProfileStore {
  static const kEmail = 'session_email';
  static const kProvider = 'session_provider';
  static const kName = 'session_name';

  final FlutterSecureStorage _storage;

  const SessionProfileStore(
      {FlutterSecureStorage storage = AppStorage.instance})
      : _storage = storage;

  /// Se llama al iniciar sesión (login con email, Google o Apple).
  Future<void> saveLogin({
    required PerfilProvider provider,
    String? email,
    String? name,
  }) async {
    try {
      await _storage.write(key: kProvider, value: provider.name);
      final e = email?.trim() ?? '';
      if (e.isNotEmpty) {
        await _storage.write(key: kEmail, value: e);
      } else {
        await _storage.delete(key: kEmail);
      }
      final n = name?.trim() ?? '';
      if (n.isNotEmpty) await _storage.write(key: kName, value: n);
    } catch (e) {
      // No rompe el login: el Perfil oculta el email si no lo tiene.
      AppLogger.warn('session-profile', 'no se pudo guardar la sesión: $e');
    }
  }

  /// Último nombre visto en el perfil (copia local para el estado de error).
  Future<void> saveName(String name) async {
    final n = name.trim();
    if (n.isEmpty) return;
    try {
      await _storage.write(key: kName, value: n);
    } catch (e) {
      AppLogger.warn('session-profile', 'no se pudo guardar el nombre: $e');
    }
  }

  Future<SessionProfile> read() async {
    try {
      final values = await Future.wait([
        _storage.read(key: kEmail),
        _storage.read(key: kProvider),
        _storage.read(key: kName),
      ]);
      return SessionProfile(
        email: values[0],
        provider: perfilProviderFrom(values[1]),
        name: values[2],
      );
    } catch (e) {
      AppLogger.warn('session-profile', 'no se pudo leer la sesión: $e');
      return SessionProfile.empty;
    }
  }

  /// Al cerrar sesión: no deja datos personales en el móvil.
  Future<void> clear() async {
    try {
      await _storage.delete(key: kEmail);
      await _storage.delete(key: kProvider);
      await _storage.delete(key: kName);
    } catch (e) {
      AppLogger.warn('session-profile', 'no se pudo borrar la sesión: $e');
    }
  }
}
